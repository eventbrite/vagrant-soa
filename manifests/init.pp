class dev {
  notify { 'Development provision!':}
  include example_service
  include local_service
}

include dev
