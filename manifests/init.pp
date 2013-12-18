class dev {
  notify { 'Development provision!':}
  include example_service
}

include dev
