name              "proxy"
maintainer        "Martin Fenner"
maintainer_email  "mfenner@datacite.org"
license           "Apache 2.0"
description       "Configures proxy"
long_description  IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version           "2.3.1"

# opscode cookbooks
depends           "apt"
depends           "openresty", "~> 0.5.4"
depends           "librato", "~> 1.1.3"

# our own cookbooks
depends           "capistrano", "~> 1.1.0"

%w{ ubuntu }.each do |platform|
  supports platform
end
