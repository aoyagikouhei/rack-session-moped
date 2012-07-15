require "rack/session/abstract/id"
require "moped"

module Rack
  module Session
    class Moped < Abstract::ID
      attr_reader :mutex, :pool, :marshal_data
      DEFAULT_OPTIONS = Abstract::ID::DEFAULT_OPTIONS.merge(
        db: :rack, 
        collection: :sessions, 
        drop: false, 
        seeds: ["localhost:27017"]
      )

      def initialize(app, options={})
        super
        @mutex = Mutex.new
        session = @default_options[:session] || ::Moped::Session.new(@default_options[:seeds])
        session.use @default_options[:db]
        @pool = session[@default_options[:collection]]
        @pool.indexes.create(expires: -1)
        @pool.indexes.create({sid: 1}, {unique: true})
        @marshal_data = @default_options[:marshal_data].nil? ? true : @default_options[:marshal_data] == true
        @next_expire_period = nil
        @recheck_expire_period = @default_options[:clear_expired_after].nil? ? 1800 : @default_options[:clear_expired_after].to_i
      end

      def get_session(env, sid)
        @mutex.lock if env['rack.multithread']
        session = find_session(sid) if sid
        unless sid and session
          env['rack.errors'].puts("Session '#{sid}' not found, initializing...") if $VERBOSE and not sid.nil?
          session = {}
          sid = generate_sid
          save_session(sid)
        end
        session.instance_variable_set('@old', {}.merge(session))
        session.instance_variable_set('@sid', sid)
        return [sid, session]
      ensure
        @mutex.unlock if env['rack.multithread']
      end

      def set_session(env, sid, new_session, options)
        @mutex.lock if env['rack.multithread']
        expires = Time.now + options[:expire_after] if !options[:expire_after].nil?
        session = find_session(sid) || {}
        if options[:renew] or options[:drop]
          delete_session(sid)
          return false if options[:drop]
          sid = generate_sid
          save_session(sid, session, expires)
        end
        old_session = new_session.instance_variable_get('@old') || {}
        session = merge_sessions(sid, old_session, new_session, session)
        save_session(sid, session, expires)
        return sid
      ensure
        @mutex.unlock if env['rack.multithread']
      end

      def destroy_session(env, sid, options)
        delete_session(sid)
        generate_sid unless options[:drop]
      end

      private

      def find_session(sid)
        time = Time.now
        if @recheck_expire_period != -1 && (@next_expire_period.nil? || @next_expire_period < time)
          @next_expire_period = time + @recheck_expire_period
          @pool.find(expires: {'$lte' => time}).remove_all # clean out expired sessions 
        end
        session = @pool.find(sid: sid).first
        #if session is expired but hasn't been cleared yet.  don't return it.
        if session && session['expires'] != nil && session['expires'] < time
          session = nil
        end
        session ? unpack(session['data']) : false
      end

      def delete_session(sid)
        @pool.find(sid: sid).remove
      end
      
      def save_session(sid, session={}, expires=nil)
        @pool.find(sid: sid).upsert("$set" => {data: pack(session), expires: expires})
      end
      
      def merge_sessions(sid, old, new, current=nil)
        current ||= {}
        unless Hash === old and Hash === new
          warn 'Bad old or new sessions provided.'
          return current
        end
        # delete keys that are not in common
        delete = current.keys - (new.keys & current.keys)
        warn "//@#{sid}: dropping #{delete*','}" if $DEBUG and not delete.empty?
        delete.each{|k| current.delete k }

        update = new.keys.select{|k| !current.has_key?(k) || new[k] != current[k] || new[k].kind_of?(Hash) || new[k].kind_of?(Array) }    
        warn "//@#{sid}: updating #{update*','}" if $DEBUG and not update.empty?
        update.each{|k| current[k] = new[k] }

        current
      end
    
      def pack(data)
        if(@marshal_data)
          [Marshal.dump(data)].pack("m*")
        else
          data
        end
      end

      def unpack(packed)
        return nil unless packed
        if(@marshal_data)
          Marshal.load(packed.unpack("m*").first)
        else
          packed
        end
      end
    end
  end
end
