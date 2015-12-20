name              "proxy"
maintainer        "Martin Fenner"
maintainer_email  "mfenner@datacite.org"
license           "Apache 2.0"
description       "Configures proxy"
long_description  IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version           "1.0.33"

# opscode cookbooks
depends           "apt"
depends           "consul"
depends           "nodejs"

# our own cookbooks
depends           "ruby", "~> 0.7.0"
depends           "passenger_nginx", "~> 1.0.0"
depends           "capistrano", "~> 1.0.0"

%w{ ubuntu }.each do |platform|
  supports platform
end
