require 'sinatra'
require 'cgi'
require 'date'

require_relative 'lib/ice_chart_fetcher'
require_relative 'lib/pdf_to_jpg_converter'
require_relative 'lib/app_helpers'

FETCHER = IceChartFetcher.new
CONVERTER = PdfToJpgConverter.new

helpers AppHelpers

# index page
get '/' do
  @page_title = 'Compare ice charts'
  @dates, @pdf_urls = FETCHER.fetch_index
  date_to_url = @dates.zip(@pdf_urls).to_h

  left_pdf_url = resolve_pdf_url(params, date_to_url, 'left')
  right_pdf_url = resolve_pdf_url(params, date_to_url, 'right')

  erb :index, locals: {
    dates: @dates,
    pdf_urls: @pdf_urls,
    left_pdf_url: left_pdf_url,
    right_pdf_url: right_pdf_url
  }
end

# convert PDF to JPG
get '/pdf_to_jpg' do
  pdf_url = params[:pdf_url]
  halt 400, 'Invalid PDF URL' unless valid_pdf_url?(pdf_url)

  begin
    jpg_path = CONVERTER.convert(pdf_url)
    send_file jpg_path, type: 'image/jpeg', disposition: 'inline'
  rescue OpenURI::HTTPError, SocketError => e
    halt 502, "Failed to fetch PDF: #{e.message}"
  end
end

# handle form submission and display images
get '/previous' do
  @page_title = 'Previous ice charts'
  @body_class = 'previous-page'
  selected_date = params[:selected_date]
  @dates, @pdf_urls = FETCHER.fetch_index
  date_to_url = @dates.zip(@pdf_urls).to_h
  selected_index = selected_date ? @dates.index(selected_date) : nil

  if selected_index
    @selected_date = selected_date
    @selected_image_url = @pdf_urls[selected_index]

    @prev_images_urls = {}
    (1..60).each do |days_before|
      begin
        prev_date = (Date.strptime(selected_date, '%d-%m-%Y') - days_before).strftime('%d-%m-%Y')
      rescue ArgumentError
        break
      end

      prev_url = date_to_url[prev_date]
      @prev_images_urls[prev_date] = prev_url if prev_url
    end
  end

  erb :previous
end
