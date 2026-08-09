require "test_helper"

class ActualsImportTest < ActiveSupport::TestCase
  setup { @user = users(:one) }

  test "imports rows and matches categories case insensitively" do
    import = build("month,category,amount\n2026-05,marketing,100\n2026-05,PAYROLL,200\n")

    assert import.save
    assert_equal 2, import.imported_count
  end

  test "an optional note column is stored" do
    import = build("month,category,amount,note\n2026-05,Marketing,100,Ad spend\n")

    assert import.save
    assert_equal "Ad spend", @user.actuals.order(:created_at).last.note
  end

  test "amounts with a currency symbol or separators are accepted" do
    import = build("month,category,amount\n2026-05,Marketing,\"$1,200.50\"\n")

    assert import.save
    assert_equal 1200.50, @user.actuals.order(:created_at).last.amount
  end

  test "missing required headers are reported" do
    import = build("month,amount\n2026-05,100\n")

    assert_not import.save
    assert_includes import.errors.full_messages.first, "must have month, category, and amount columns"
  end

  test "a single bad row rolls back the whole file" do
    import = build("month,category,amount\n2026-05,Marketing,100\n2026-05,Marketing,abc\n")

    assert_no_difference -> { Actual.count } do
      assert_not import.save
    end

    assert_includes import.errors.full_messages, "Row 3: amount \"abc\" is not a number."
  end

  test "a locked month rolls back the whole file" do
    @user.period_locks.create!(month: "2026-05")
    import = build("month,category,amount\n2026-05,Marketing,100\n")

    assert_no_difference -> { Actual.count } do
      assert_not import.save
    end
  end

  test "a negative amount rolls back the whole file" do
    import = build("month,category,amount\n2026-05,Marketing,100\n2026-05,Payroll,-20\n")

    assert_no_difference -> { Actual.count } do
      assert_not import.save
    end

    assert_includes import.errors.full_messages, "Row 3: Amount must be greater than or equal to 0"
  end

  test "the template lists the expected columns and parses cleanly" do
    rows = CSV.parse(ActualsImport.template_csv)

    assert_equal %w[ month category amount note ], rows.first
    assert_equal [ "2026-01", "Marketing", "4800", "Q1 ad campaign" ], rows.second
  end

  test "the template can be imported as-is once the categories exist" do
    import = ActualsImport.new(user: @user, file: StringIO.new(ActualsImport.template_csv))

    assert import.save, import.errors.full_messages.to_sentence
    assert_equal 3, import.imported_count
  end

  test "a file over the size limit is rejected" do
    oversized = StringIO.new("x" * (ActualsImport::MAX_BYTES + 1))
    import = ActualsImport.new(user: @user, file: oversized)

    assert_not import.save
    assert_includes import.errors.full_messages.first, "or smaller"
  end

  test "a file is required" do
    import = ActualsImport.new(user: @user)

    assert_not import.save
    assert_includes import.errors.full_messages, "File is required"
  end

  test "an empty file is reported" do
    import = build("month,category,amount\n")

    assert_not import.save
    assert_includes import.errors.full_messages, "CSV has no rows."
  end

  private
    def build(content)
      ActualsImport.new(user: @user, file: StringIO.new(content))
    end
end
