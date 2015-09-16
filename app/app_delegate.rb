class AppDelegate
  def application(application, didFinishLaunchingWithOptions:launchOptions)

    Parse.setApplicationId(ENV['PARSE_APPLICATION_ID'], clientKey: ENV['PARSE_CLIENT_KEY'])

    true
  end
end
