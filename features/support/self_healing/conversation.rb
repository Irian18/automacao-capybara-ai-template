require 'json'

module SelfHealing
  class Conversation
    def initialize
      @messages = []
    end

    def system(content)
      @messages << { 'role' => 'system', 'content' => content }
    end

    def user(content)
      @messages << { 'role' => 'user', 'content' => content }
    end

    def assistant(message, tool_calls: [])
      clean = { 'role' => message['role'], 'content' => message['content'] || '' }
      clean['tool_calls']        = tool_calls if tool_calls.any?
      clean['reasoning_content'] = message['reasoning_content'] if message['reasoning_content']
      @messages << clean
    end

    def tool(tool_call_id:, name:, content:)
      @messages << {
        'role' => 'tool',
        'tool_call_id' => tool_call_id,
        'name' => name,
        'content' => content.to_s
      }
    end

    def messages
      @messages.dup
    end

    def empty?
      @messages.empty?
    end

    def clear
      @messages = []
    end
  end
end
