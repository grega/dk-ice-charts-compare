module AppHelpers
  def resolve_pdf_url(params, date_to_url, side)
    direct_url = params[side]
    return direct_url if direct_url

    date_param = params["#{side}_date"]
    return date_to_url[date_param] if date_param

    nil
  end

  def valid_pdf_url?(pdf_url)
    return false unless pdf_url

    pdf_url.start_with?('https://ocean.dmi.dk/arctic/') && pdf_url.end_with?('.pdf')
  end
end
