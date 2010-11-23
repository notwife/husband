God.pid_file_directory = File.expand_path("../pids",__FILE__)

God.watch do |w|
  w.name = "fetcher"
  w.interval = 3.second
  w.dir = File.expand_path("../../",__FILE__)
  log = File.expand_path("../log/#{w.name}.log",__FILE__)
  w.start = "ruby #{File.dirname(__FILE__)}/#{w.name}.rb #{log}"

  w.start_if do |start|
    start.condition(:process_running) do |c|
      c.running = false
    end
  end
end

God.watch do |w|
  w.name = "stream_to_notwife"
  w.interval = 3.second
  w.dir = "#{File.dirname(__FILE__)}/../"
  log = File.expand_path("../log/#{w.name}.log",__FILE__)
  w.start = "ruby #{File.dirname(__FILE__)}/#{w.name}.rb #{log}"

  w.start_if do |start|
    start.condition(:process_running) do |c|
      c.running = false
    end
  end
end

God.watch do |w|
  w.name = "notifier"
  w.interval = 15.second
  w.dir = "#{File.dirname(__FILE__)}/../"
  log = File.expand_path("../log/#{w.name}.log",__FILE__)
  w.start = "ruby #{File.dirname(__FILE__)}/#{w.name}.rb #{log}"

  w.start_if do |start|
    start.condition(:process_running) do |c|
      c.running = false
    end
  end
end
