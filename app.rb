require 'sinatra'
require 'nokogiri'
require 'open-uri'
require 'cgi'
require 'mini_magick'

def fetch_dates_and_urls
  url = 'https://ocean.dmi.dk/arctic/icecharts_capefarewell_frame_content.php'
  
  doc = Nokogiri::HTML(URI.open(url))
  dates = []
  pdf_urls = []
  td_elements = doc.css('td')

  td_elements.each do |td|
    input_element = td.at_css('input[name="selected_modis_img"]')

    if input_element && input_element['value']
      pdf_url = input_element['value']
      date = pdf_url[/\d{12}/]
      human_readable_date = "#{date[6..7]}-#{date[4..5]}-#{date[0..3]}"

      dates << human_readable_date
      pdf_urls << "https://ocean.dmi.dk/arctic/#{pdf_url}.pdf"
    end
  end

  [dates, pdf_urls]
end

# index page
get '/' do
  @dates, @pdf_urls = fetch_dates_and_urls
  date_to_url = @dates.zip(@pdf_urls).to_h

  # try to get full PDF URLs from params
  left_pdf_url = params[:left]
  right_pdf_url = params[:right]

  # or resolve from date params if present
  if !left_pdf_url && params[:left_date]
    left_pdf_url = date_to_url[params[:left_date]]
  end

  if !right_pdf_url && params[:right_date]
    right_pdf_url = date_to_url[params[:right_date]]
  end

  # fallback to latest available PDF
  # left_pdf_url ||= @pdf_urls.first
  # right_pdf_url ||= @pdf_urls.first

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

  # generate a unique filename based on the PDF URL
  jpg_filename = "#{CGI.escape(pdf_url)}.jpg"
  jpg_path = File.join('tmp', 'images', jpg_filename)

  unless File.exist?(jpg_path)
    pdf_data = URI.open(pdf_url).read
    pdf_path = "tmp/temp.pdf"
    File.write(pdf_path, pdf_data)
    
    MiniMagick::Tool::Convert.new do |convert|
      convert.background 'white'
      convert.alpha 'remove'
      convert.quality '100'
      convert.resize '800x'
      convert << pdf_path
      convert << jpg_path
    end
  end

  send_file jpg_path, type: 'image/jpeg', disposition: 'inline'
end

# handle form submission and display images
get '/previous' do
  selected_date = params[:selected_date]
  dates, pdf_urls = fetch_dates_and_urls
  selected_index = dates.index(selected_date)

  if selected_index
    @selected_date = selected_date
    @selected_image_url = pdf_urls[selected_index]

    @prev_images_urls = {}
    (1..60).each do |days_before|
      prev_date = (Date.parse(selected_date) - days_before).strftime("%d-%m-%Y")
      prev_index = dates.index(prev_date)
      if prev_index
        @prev_images_urls[prev_date] = pdf_urls[prev_index]
      end
    end
  end

  erb :previous, locals: { dates: dates, pdf_urls: pdf_urls }
end
