require "Parsistence/version"

Motion::Project::App.setup do |app|
  app.pods do
    pod 'Parse'
  end
  Dir.glob(File.join(File.dirname(__FILE__), "Parsistence/*.rb")).each do |file|
    app.files.unshift(file) unless file.include? "Model.rb"
  end
  app.files.unshift(File.join(File.dirname(__FILE__), "Parsistence/Model.rb"))
end
