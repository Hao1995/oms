module Agent
  class Factory
    def self.get_agent(agent_name)
      case agent_name
      when 'megaphone'
        Agent::MegaphoneAgent.new(agent_name)
      else
        raise "Unknown agent: #{agent_name}"
      end
    end
  end
end
