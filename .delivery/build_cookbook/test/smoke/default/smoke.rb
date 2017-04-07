my_host_endpoint = attribute('host_endpoint', default: 'http://www.google.com', description: 'The host endpoint to test')

describe http(my_host_endpoint) do
  its('status') { should cmp 200 }
end
