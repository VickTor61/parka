InlineSvg.configure do |config|
  config.asset_file = InlineSvg::CachedAssetFile.new(
    paths: [
      Rails.root.join("app", "assets", "images", "icons")
    ]
  )
end
