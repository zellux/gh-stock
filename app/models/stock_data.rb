#encoding: utf-8
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
      current_total = data.inject(0.0) { |a, e| a + e['zzc'].to_f } / data.size
      last_month_total = data.inject(0.0) { |a, e| a + e['zzc'].to_f / (1 + e['yyll'].to_f / 100) } / data.size
      last_week_total = data.inject(0.0) { |a, e| a + e['zzc'].to_f / (1 + e['zyll2'].to_f / 100) } / data.size
      last_day_total = data.inject(0.0) { |a, e| a + e['zzc'].to_f / (1 + e['ryll'].to_f / 100) } / data.size
      Rails.logger.debug(last_month_total)
      total = {
        'pm' => '',
        'userName' => '总计',
        'zyll1' => '%.2f%' % (current_total / 10000.0 - 100.0),
        'yyll' => '%.2f%' % (current_total / last_month_total * 100 - 100.0),
        'zyll2' => '%.2f%' % (current_total / last_week_total * 100 - 100.0),
        'ryll' => '%.2f%' % (current_total / last_day_total * 100 - 100.0),
        'zzc' => '%.2f' % current_total
      } rescue nil
      data += [total] if total
      data
    end

    def data
      if Rails.cache.fetch('last-update') == nil || Time.now - Rails.cache.fetch('last-update') > 60 * 60
        Rails.cache.write('stock-data', merge_table)
        Rails.cache.write('last-update', Time.now)
      end
      Rails.cache.fetch('stock-data')
    end

    def clean_cache
      Rails.cache.delete('stock-data')
      Rails.cache.delete('last-update')
    end

    def updated_at
      Rails.cache.fetch('last-update').localtime("+08:00").strftime('%Y-%m-%d %H:%M:%S')
    end

    def to_clipboard
      def count_mb(str)
        count = 0
        str.split(//).each {|c|
          count += 1 if (c.bytesize != c.length)
        }
        count
      end
      "排名 用户名       总盈利率 月盈利率 周盈利率 日盈利率      总资产\n" +
      data.map do |line|
        name_len = 14 - count_mb(line['userName'])
        "%-4s%-#{name_len}s%9s%11s%11s%11s%13s" % ['pm', 'userName', 'zyll1', 'yyll', 'zyll2', 'ryll', 'zzc'].map { |e| line[e] }
      end.join("\n")
    end
  end
end
