workers Integer(ENV['WEB_CONCURRENCY'] || 2)
threads_count = Integer(ENV['THREAD_COUNT'] || 5)
threads threads_count, threads_count

port        ENV['PORT']     || 4567
environment ENV['RACK_ENV'] || 'development'
