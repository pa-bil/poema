class Admin::ChartsController < ApplicationController
  access_control do
    allow :root
  end
  
  def show
    @counters = StatCounterObject.all
  end
  
  def data
    handles = (params[:handles] ? params[:handles] : [])
    show_days = params[:days]

    queries = []
    if show_days.to_i > 0
      handles.each do |h|
        o = StatCounterObject.find_by_handle! h
        queries.push({
          :title   => (o.description.nil? ? o.handle : o.description),
          :records => StatCounter.list_daily(o, Date.today - (show_days.to_i))
        })
      end
      label_date_format = "%d %B %Y"
    else
      handles.each do |h|
        o = StatCounterObject.find_by_handle! h
        queries.push({
          :title   => (o.description.nil? ? o.handle : o.description),
          :records => StatCounter.list_monthly(o)
        })
      end
      label_date_format = "%B %Y"
    end

    # Kompozycja wyniku
    # 0: komponuję pierwszą kolumnę z tytułami
    # 1: sprawdzamy, czy każdy handle ma tyle samo elementów
    # 2: składamy tablicę
    values = []
    if queries.count > 0
      row = ['']
      queries.each do |query|
        row.push(query[:title])
      end
      values.push(row)

      expected_count = (queries.first[:records].count - 1)
      (0..expected_count).each do |i|
        row = []
        first = true
        queries.each do |query|
          r = query[:records].at(i)
          if first
            row.push(I18n.localize(Date.new(r['y'].to_i, r['m'].to_i, r['d'].to_i)))
            first = false
          end
          row.push(r['value'].to_i)
        end
        values.push(row)
      end
    end
    results = {
      :handlers => handles,
      :title    => "Wykres",
      :values   => values
    }
    render :json => {:total => values.count, :offset => 0, :results => results}.to_json
  end
end
