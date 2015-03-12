#
# Stoplight Provider for Travis CI (http://travis-ci.org)
#
# Travis does not conform to the multi-project reporting spec, so
# we need to define our own provider
#
require 'travis'

TravisClient = Travis;

module Stoplight::Providers
  include TravisClient
  class Travis < Provider
    # Initializes a hash `@options` of default options
    def initialize(options = {})
      if options['url'].nil?
        raise ArgumentError, "'url' must be supplied as an option to the Provider. Please add 'url' => '...' to your hash."
      end

      @options = options
    end

    def provider
      'travis'
    end

    def builds_path
      @options['builds_path'] ||= 'repositories.json'
    end

    def projects
      if (@options['build_url'] || '').include? "magnum"
        TravisClient::Pro.access_token = @options['access_token']
        repositories = TravisClient::Pro::Repository.find_all(owner_name: @options['owner_name']);
      else
        TravisClient.access_token = @options['access_token']
        repositories = TravisClient::Repository.find_all(owner_name: @options['owner_name']);
      end

      @projects = @projects || []

      repositories.each do |repository|
        name = repository.slug.split(/\//).last;
        if @options['projects'] and not @options['projects'].include? name
          next
        end

        culprits = ''
        if repository.last_build
          culprits = repository.last_build.commit.author_name
        end

        @projects << Stoplight::Project.new({
             :name => name,
             :build_url => "#{@options['build_url']}/#{repository['slug']}",
             :last_build_id => repository.last_build_number.to_s,
             :last_build_time => repository.last_build_finished_at.to_s,
             :last_build_status => status_to_int(repository.last_build_state),
             :current_status => repository.last_build_state === "failed" ? -1 : 0,
             :culprits => culprits
         })
      end

      @projects
    end

    private
    def status_to_int(status)
      status || -1
    end

    def current_status_to_int(status)
      return 1 if status.nil? # building
      begin
        DateTime.parse(status)
        0
      rescue ArgumentError
        -1
      end
    end
  end
end
