#
# Be sure to run `pod lib lint SwiftCharReader.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'SwiftCharReader'
  s.version          = '1.0'
  s.summary          = 'Read text file character by character.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
  Read text file (UTF8) character by character.
                       DESC

  s.homepage         = 'https://github.com/soleilpqd/SwiftCharReader'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'DuongPQ' => 'soleilpqd@gmail.com' }
  s.source           = { :git => 'https://github.com/soleilpqd/SwiftCharReader.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '8.0'

  s.source_files = 'SwiftCharReader/**/*'

end
