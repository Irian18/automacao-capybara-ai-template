module GoogleSheetsHelper
  def integration_google_sheets
    application_name = CONFIG['application_name']
    credentials_path = CONFIG['credentials_googleSheets_performance_path']
    scope = CONFIG['scope'] || Google::Apis::SheetsV4::AUTH_SPREADSHEETS

    raise '[GoogleSheetsHelper] credentials_googleSheets_performance_path não configurado' unless credentials_path

    service = Google::Apis::SheetsV4::SheetsService.new
    service.client_options.application_name = application_name
    service.authorization = Google::Auth::ServiceAccountCredentials.make_creds(
      json_key_io: File.open(credentials_path),
      scope: scope
    )
    service
  end

  def update_spreadsheet_value(spreadsheet_id:, range:, values:, value_input_option: 'RAW')
    service = integration_google_sheets
    value_range_object = Google::Apis::SheetsV4::ValueRange.new(range: range, values: values)
    service.update_spreadsheet_value(spreadsheet_id, range, value_range_object, value_input_option: value_input_option)
  end

  def clear_spreadsheet_range(spreadsheet_id:, range:)
    service = integration_google_sheets
    service.clear_values(spreadsheet_id, range, Google::Apis::SheetsV4::ClearValuesRequest.new)
  end

  def return_last_row_with_value_by_gs(spreadsheet_id:, sheet_name:, column: 'B')
    service = integration_google_sheets
    range = "#{sheet_name}!#{column}:#{column}"
    response = service.get_spreadsheet_values(spreadsheet_id, range)

    return 1 if response.values.nil? || response.values.empty?

    last_row = response.values.size
    response.values.reverse.each_with_index do |row, index|
      next if row[0].nil? || row[0].empty?

      return response.values.size - index + 1
    end
    last_row
  end
end
