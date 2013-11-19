
class ChompyImageSearch

  def chat(text)
    image_search($1.strip) if text =~ /showme(.*)$/
  end

  protected

  def image_search(search_text)
    puts "Image searching: #{search_text}"

    url = "https://ajax.googleapis.com/ajax/services/search/images?v=1.0&q=#{CGI::escape(search_text)}"
    uri = URI.parse(url)

    begin
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true

      request = Net::HTTP::Get.new(uri.request_uri, {
        'Referer' => 'http://tailorwell.com'
      })
      response = http.request(request)

      results = JSON.load(response.body)
      img = results['responseData']['results'].first
      image_chat(img['tbUrl'], img['originalContextUrl'])      
    rescue
      'search failed'
    end
  end

end

Chompy.register(ChompyImageSearch)