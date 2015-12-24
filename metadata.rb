name              "proxy"
maintainer        "Martin Fenner"
maintainer_email  "mfenner@datacite.org"
license           "Apache 2.0"
description       "Configures proxy"
long_description  IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version           "1.1.3"

# opscode cookbooks
depends           "apt"
depends           "consul"
depends           "openssl"
depends           "ssl_certificate"
depends           "openresty"

# our own cookbooks
depends           "capistrano", "~> 1.0.0"

%w{ ubuntu }.each do |platform|
  supports platform
end
