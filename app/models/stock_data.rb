require "uri"
require "net/http"

class StockData
  # attr_accessible :title, :body
  class << self
    def fetch_remote_json(page=1)
      url = 'http://moni.10jqka.com.cn/hezuo/index/searchph/fudanstock2012y'
      params = {
        page: page,
        orderField: 2
      }
      body = Net::HTTP.post_form(URI.parse(url), params).body
      ActiveSupport::JSON.decode(body)
    end

    def merge_table
      json = fetch_remote_json(1)
      data = json['result']['pmData']
      2.upto(json['result']['pages']['pageCount']) do |i|
        data += fetch_remote_json(i)['result']['pmData']
      end
      data
    end

    def data
      Rails.cache.fetch('stock-data', expire_in: 3600) do
        Rails.cache.write('last-update', Time.now)
        merge_table
      end
    end

    def clean_cache
      Rails.cache.delete('stock-data')
    end

    def updated_at
      Rails.cache.fetch('last-update').localtime("+08:00").strftime('%Y-%m-%d %H:%M:%S')
    end
  end
end
