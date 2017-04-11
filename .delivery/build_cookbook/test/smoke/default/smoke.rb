my_host_endpoint = attribute('host_endpoint', default: 'http://www.google.com', description: 'The host endpoint to test')

begin
  require 'resolv'
  require 'uri'
  retries ||= 0
  Resolv.getaddress(URI.parse(my_host_endpoint).host)
  describe http(my_host_endpoint) do
    its('status') { should cmp 200 }
    its('body') { should match /National Parks/ }
    its('headers.content-type') { should match /text\/html/ }
  end
rescue
  puts "Waiting for #{my_host_endpoint} to become available..."
  sleep 10
  if (retries += 1) < 15
    retry
  else
    raise "Failed to resolve #{my_host_endpoint} after 150 seconds..."
  end
end

  

