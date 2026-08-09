require "csv"

class ActualsImport
  include ActiveModel::Model

  REQUIRED_HEADERS = %w[ month category amount ].freeze
  MAX_ROWS = 5_000

  attr_accessor :file
  attr_reader :imported_count

  validates :file, presence: { message: "is required" }

  def initialize(user:, file: nil)
    @user = user
    @file = file
    @imported_count = 0
  end

  def save
    return false unless valid?

    rows = parse
    return false if errors.any?

    import(rows)
    errors.empty?
  end

  private
    attr_reader :user

    def parse
      table = CSV.parse(read_file, headers: true)

      unless (REQUIRED_HEADERS - normalized_headers(table)).empty?
        errors.add(:base, "CSV must have #{REQUIRED_HEADERS.to_sentence} columns.")
        return []
      end

      if table.size > MAX_ROWS
        errors.add(:base, "CSV has #{table.size} rows, the limit is #{MAX_ROWS}.")
        return []
      end

      errors.add(:base, "CSV has no rows.") if table.size.zero?
      table.each_with_index.map { |row, index| build_row(row, index + 2) }
    rescue CSV::MalformedCSVError => e
      errors.add(:base, "CSV could not be parsed: #{e.message}")
      []
    end

    def read_file
      file.read.to_s.force_encoding(Encoding::UTF_8).scrub
    end

    def normalized_headers(table)
      table.headers.compact.map { |header| header.to_s.strip.downcase }
    end

    def build_row(row, line)
      values = row.to_h.transform_keys { |key| key.to_s.strip.downcase }

      {
        line: line,
        month: values["month"].to_s.strip,
        category_name: values["category"].to_s.strip,
        amount: values["amount"].to_s.strip,
        note: values["note"].to_s.strip.presence
      }
    end

    def import(rows)
      ActiveRecord::Base.transaction do
        rows.each { |row| import_row(row) }

        raise ActiveRecord::Rollback if errors.any?
      end
    end

    def import_row(row)
      category = categories[row[:category_name].downcase]

      if row[:category_name].blank?
        return errors.add(:base, "Row #{row[:line]}: category is required.")
      elsif category.nil?
        return errors.add(:base, "Row #{row[:line]}: category \"#{row[:category_name]}\" does not exist.")
      end

      unless valid_amount?(row[:amount])
        return errors.add(:base, "Row #{row[:line]}: amount \"#{row[:amount]}\" is not a number.")
      end

      actual = user.actuals.new(category: category, month: row[:month], amount: cleaned_amount(row[:amount]), note: row[:note])

      if actual.save
        @imported_count += 1
      else
        errors.add(:base, "Row #{row[:line]}: #{actual.errors.full_messages.to_sentence}")
      end
    end

    def categories
      @categories ||= user.categories.index_by { |category| category.name.downcase }
    end

    def cleaned_amount(value)
      value.to_s.delete("$,").strip
    end

    def valid_amount?(value)
      Float(cleaned_amount(value))
      true
    rescue ArgumentError, TypeError
      false
    end
end
