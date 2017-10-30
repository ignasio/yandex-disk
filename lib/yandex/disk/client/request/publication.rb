require 'nokogiri'

class Yandex::Disk::Client::Request::Publication

  PUBLISHBODY = '<propertyupdate xmlns="DAV:">
    <set>
        <prop>
              <public_url xmlns="urn:yandex:disk:meta">true</public_url>
        </prop>
    </set>
  </propertyupdate>'

  UNPUBLISHBODY = '<propertyupdate xmlns="DAV:">
    <remove>
        <prop>
              <public_url xmlns="urn:yandex:disk:meta" />
        </prop>
    </remove>
  </propertyupdate>'

  CHECKBODY = '<propfind xmlns="DAV:">
    <prop>
        <public_url xmlns="urn:yandex:disk:meta"/>
    </prop>
  </propfind>'

  HEADERS = {
    :Depth => 0
  }

  def initialize(http,url)
    @url  = url
    @http = http
  end

  %w(publish unpublish check).each do |_method|
    define_method _method do
      response = @http.run_request _method=="check" ? :propfind : :proppatch, @url, "#{self.class}::#{_method.upcase}BODY".constantize, HEADERS

      if response.body.present?
        parse_result = parse(response.body)
        parse_result.public_url
      end
    end
  end

  private

  class AttributesParser < Nokogiri::XML::SAX::Document
    attr_reader :public_url

    def start_element name, attributes = []
      @is_public_url = true if name == 'public_url'
    end

    def characters string
      @public_url = string if @is_public_url
    end
  end

  def parse body
    attributes_parser = AttributesParser.new

    parser = Nokogiri::XML::SAX::Parser.new(attributes_parser)
    parser.parse(body)

    attributes_parser
  end
end
