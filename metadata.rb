name              "proxy"
maintainer        "Martin Fenner"
maintainer_email  "mfenner@datacite.org"
license           "Apache 2.0"
description       "Configures proxy"
long_description  IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version           "2.1.23"

# opscode cookbooks
depends           "apt"
depends           "ssl_certificate"
depends           "openresty", "~> 0.5.4"

# our own cookbooks
depends           "capistrano", "~> 1.1.0"

%w{ ubuntu }.each do |platform|
  supports platform
end
