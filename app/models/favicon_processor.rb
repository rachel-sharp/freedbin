class FaviconProcessor

  S3_POOL = ConnectionPool.new(size: 10, timeout: 5) do
    Fog::Storage.new(
      provider: "AWS",
      aws_access_key_id: ENV["AWS_ACCESS_KEY_ID_FAVICONS"],
      aws_secret_access_key: ENV["AWS_SECRET_ACCESS_KEY_FAVICONS"],
      persistent: true
    )
  end

  attr_reader :data

  def initialize(data)
    @data = data
  end

  def favicon_url
    @favicon_url ||= upload(image_data)
  end

  def encoded_favicon
    @encoded_favicon ||= encoded(image_data)
  end

  def valid?
    data.present?
  end

  private

  def favicon_hash
    @favicon_hash ||= Digest::SHA1.hexdigest(data)
  end

  def image_data
    @image_data ||= get_image_data
  end

  def get_image_data
    layers = load_layers
    favicon = remove_blank_images(layers).last
    if favicon.columns > 32
      favicon = favicon.resize_to_fit(32, 32)
    end
    favicon.to_blob { |image| image.format = 'png' }
  rescue
    nil
  ensure
    favicon && favicon.destroy!
    layers && layers.map(&:destroy!)
  end

  def encoded(blob)
    Base64.encode64(blob).gsub("\n", '')
  end

  def load_layers
    begin
      Magick::Image.from_blob(data)
    rescue Magick::ImageMagickError
      Magick::Image.from_blob(data) { |image| image.format = 'ico' }
    end
  end

  def remove_blank_images
    favicons.reject do |favicon|
      favicon = favicon.scale(1, 1)
      pixel = favicon.pixel_color(0,0)
      favicon.to_color(pixel) == "none"
    end
  end

  def upload(data)
    upload_url = nil
    S3_POOL.with do |connection|
      response = connection.put_object(ENV['AWS_S3_BUCKET_FAVICONS'], path, data, s3_options)
      upload_url = URI::HTTP.build(
        scheme: 'https',
        host: response.data[:host],
        path: response.data[:path]
      ).to_s
    end
    upload_url
  end

  def s3_options
    {
      "Content-Type" => "image/png",
      "Cache-Control" => "max-age=315360000, public",
      "Expires" => "Sun, 29 Jun 2036 17:48:34 GMT",
      "x-amz-acl" => "public-read",
      "x-amz-storage-class" => "REDUCED_REDUNDANCY"
    }
  end

  def path
    @path ||= File.join(favicon_hash[0..3], "#{favicon_hash}.png")
  end
end