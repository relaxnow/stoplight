#
# Stoplight Provider for ThoughtWorks Go CI (http://jenkinsci.org)
#
#require 'xmlsimple'
require 'crack'
module Stoplight::Providers
  class ThoughtworksGo < MultiProjectStandard
    def provider
      'thoughtworks_go'
    end

    def builds_path
      'go/cctray.xml'
    end

    #def projects
    #  xml = XmlSimple.xml_in(@response.parsed_response)
    #  xml["Project"].collect do |project|
    #    Stoplight::Project.new({
    #       :name => project['name'],
    #       :build_url => project['webUrl'],
    #       :last_build_id => project['lastBuildLabel'],
    #       :last_build_time => project['lastBuildTime'],
    #       :last_build_status => status_to_int(project['lastBuildStatus']),
    #       :current_status => activity_to_int(project['activity'])
    #       #:culprits =>
    #      })
    #  end
    #end

    def projects
      xmlHash = Crack::XML.parse(@response)
      xmlHash["Projects"]["Project"].collect do |project|
        Stoplight::Project.new({
                                   :name => project['name'],
                                   :build_url => project['webUrl'],
                                   :last_build_id => project['lastBuildLabel'],
                                   :last_build_time => project['lastBuildTime'],
                                   :last_build_status => status_to_int(project['lastBuildStatus']),
                                   :current_status => activity_to_int(project['activity']),
                                   :culprits => get_culprits(project)
                               })
      end
    end

    private
    def get_culprits project
      if !project['messages'].nil?
        return project['messages']['message']['text']
      else
        return []
      end
    end
  end
end
