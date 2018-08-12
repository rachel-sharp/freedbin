require 'test_helper'

class IframeEmbedTest < ActiveSupport::TestCase

  test "should return youtube handler" do
    url = "https://youtube.com/embed/1234"

    stub_request_file("oembed.json", /www\.youtube\.com/, headers: {"Content-Type" => "application/json; charset=utf-8"})

    klass = IframeEmbed.fetch(url)
    assert_instance_of IframeEmbed::Youtube, klass
  end

  test "should return default handler" do
    url = "https://myembedservice.com/1234"

    klass = IframeEmbed.fetch(url)
    assert_instance_of IframeEmbed::Default, klass
  end

  test "should have embed properties" do
    stub_request_file("oembed.json", /.*/, headers: {"Content-Type" => "application/json; charset=utf-8"})

    embed_sources = {
      IframeEmbed::Youtube     => "https://www.youtube-nocookie.com/embed/VfKcLAwFJTo",
      IframeEmbed::Vimeo       => "https://player.vimeo.com/video/283748810",
      IframeEmbed::Ted         => "https://embed.ted.com/talks/jill_bolte_taylor_s_powerful_stroke_of_insight",
      IframeEmbed::Kickstarter => "https://www.kickstarter.com/projects/1115015686/help-support-the-kiggins-theatre-to-go-digital/widget/video.html",
      IframeEmbed::Soundcloud  => "https://w.soundcloud.com/player/?visual=true&url=https%3A%2F%2Fapi.soundcloud.com%2Ftracks%2F293&show_artwork=true",
      IframeEmbed::Spotify     => "https://open.spotify.com/embed/artist/7ae4vgLLhir2MCjyhgbGOQ",
    }

    embed_sources.each do |klass, url|
      object = IframeEmbed.fetch(url)

      parsed_url = URI(url)

      assert_instance_of klass, object
      assert_not_nil object.canonical_url, "#{klass} should have canonical_url"
      assert_not_nil object.clean_name, "#{klass} should have clean_name"
      assert object.embed_url_data, "#{klass} should have embed_url_data"
      assert_instance_of Hash, object.iframe_params, "#{klass} should have iframe_params"
      assert object.iframe_src.include?(parsed_url.host), "iframe source should include host"
      assert_not_nil object.image_url, "#{klass} should have image_url"
      assert_equal "YouTube", object.subtitle, "#{klass} should have subtitle"
      assert_equal "Samsung Galaxy Note 9 Impressions: Underrated!", object.title, "#{klass} should have title"
      assert_equal "video", object.type, "#{klass} should have type"
      assert_instance_of Hash, object.oembed_params, "#{klass} should have oembed_params"
      assert_instance_of String, object.oembed_url, "#{klass} should have oembed_url"
    end
  end


end