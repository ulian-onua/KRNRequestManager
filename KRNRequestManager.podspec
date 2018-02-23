
Pod::Spec.new do |s|

  s.name         = "KRNRequestManager"
  s.version      = "0.0.4"
  s.summary      = "KRNRequestManager is a wrapper of NSURLSession to simplify REST requests"

  s.homepage     = "https://github.com/ulian-onua/KRNRequestManager"

  s.license      = { :type => "MIT", :file => "LICENSE" }



  s.author             = { "Julian Drapaylo" => "ulian.onua@gmail.com" }
#s.social_media_url   = "http://www.linkedin.com/in/julian-drapaylo"



  s.platform     = :ios, "8.0"

  s.source       = { :git => "https://github.com/ulian-onua/KRNRequestManager.git", :tag => "0.0.4" }


  s.source_files  = "Source/*.{swift}"
#s.public_header_files = "Source/*.{swift}"

 s.pod_target_xcconfig = {
    'SWIFT_VERSION' => '4.0',
  }

  s.frameworks = "Foundation"
  s.requires_arc = true

end