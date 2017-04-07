my_host_endpoint = attribute('host_endpoint', default: 'http://www.google.com', description: 'The host endpoint to test')

describe http(my_host_endpoint) do
  its('status') { should cmp 200 }
  its('body') { should match /National Parks/ }
  its('headers.content-type') { should match /text\/html/ }
end
