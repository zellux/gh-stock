class HomeController < ApplicationController
  def index
    @data = StockData.data
    @updated_at = StockData.updated_at
  end

  def refresh
    StockData.clean_cache
    redirect_to root_path
  end
end
