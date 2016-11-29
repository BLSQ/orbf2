
module WebmockDhis2Helpers
  def stub_dhis2_system_info_success(dhis2_url)
    stub_request(:get, "#{dhis2_url}/api/system/info")
      .to_return(status: 200, body: '{ "version":"2.25" }', headers: {})
  end

  def stub_dhis2_system_info_error(dhis2_url)
    stub_request(:get, "#{dhis2_url}/api/system/info")
      .to_return(status: 401, body: '<!DOCTYPE html><html><head><title>Apache Tomcat/8.0.32 - Error report</title><style type="text/css">H1 {font-family:Tahoma,Arial,sans-serif;color:white;background-color:#525D76;font-size:22px;} H2 {font-family:Tahoma,Arial,sans-serif;color:white;background-color:#525D76;font-size:16px;} H3 {font-family:Tahoma,Arial,sans-serif;color:white;background-color:#525D76;font-size:14px;} BODY {font-family:Tahoma,Arial,sans-serif;color:black;background-color:white;} B {font-family:Tahoma,Arial,sans-serif;color:white;background-color:#525D76;} P {font-family:Tahoma,Arial,sans-serif;background:white;color:black;font-size:12px;}A {color : black;}A.name {color : black;}.line {height: 1px; background-color: #525D76; border: none;}</style> </head><body><h1>HTTP Status 401 - LDAP authentication is not configured</h1><div class="line"></div><p><b>type</b> Status report</p><p><b>message</b> <u>LDAP authentication is not configured</u></p><p><b>description</b> <u>This request requires HTTP authentication.</u></p><hr class="l>', headers: {})
  end
end
