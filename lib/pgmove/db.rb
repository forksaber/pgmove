require_relative 'helper'
require 'pg'

module Pgmove
  class Db

    include Helper
    attr_reader :user, :pass, :host, :port, :name

    def initialize(name:, user:, pass:, host:, port:, use_tmp: false)
      @user = user
      @pass = pass
      @host = host
      @port = port

      if use_tmp
        @name = "#{name}_bucardo_tmp"
        @final_name = name
      else
        @name = name
      end
    end

    def reset
      psql "DROP DATABASE IF EXISTS #{@name}", db: "postgres"
      psql "CREATE DATABASE #{@name}", db: "postgres"
    end

    def load_schema(path)
      psql_raw "-f #{path}"
    end

    def finalize
      psql "ALTER DATABASE #{@name} RENAME to #{@final_name}", db: "postgres"
    end

    def superuser?
      rows = psql_query "select usesuper from pg_user where usename = CURRENT_USER"
      rows[0][0] == 't'
    end

    def conn_str(db: nil)
      db ||= @name
      "host=#{@host} port=#{@port} dbname=#{db} user=#{@user} password=#{@pass}"
    end

    def bucardo_conn_str
      "dbhost=#{@host} dbport=#{@port} dbname=#{@name} dbuser=#{@user} password=#{@pass}"
    end

    def tables
      tables = []
      schemas.each do |s|
        sql = "SELECT table_name FROM information_schema.tables \
             WHERE table_schema='#{s}' AND table_type='BASE TABLE'"
         rows = psql_query sql
         rows.each { |r| tables << "#{s}.#{r[0]}" }
      end
      tables.sort
    end

    def schemas
      sql = "SELECT n.nspname FROM pg_catalog.pg_namespace n WHERE n.nspname !~ '^pg_' AND n.nspname <> 'information_schema' AND n.nspname <> 'bucardo'"
      rows = psql_query sql
      rows.map { |r| r[0] }
    end

    def row_count(table, conn:)
      sql = "select count(*) from #{table}"
      conn.exec(sql)[0]["count"].to_i
    rescue
      -1
    end

    def compare(other_db)
      row_counts = row_counts()
      other_row_counts = other_db.row_counts
      row_counts.each do |k, v|
        printf "%-60s %15d %15d\n", k, row_counts[k], other_row_counts[k]
      end
    end

    def pg_conn
      conn = PG::Connection.open(
        :dbname => @name, 
        :user => @user, 
        :password => @pass, 
        :host => @host, 
        :port => @port
      )
      if block_given?
        yield conn
      else
        conn
      end
    ensure
      if block_given?
        conn.close if conn
      end
    end

    private
 
    def psql(sql, db: nil)
      psql_raw %(-c "#{sql}"), db: db
    end

    def psql_raw(params, db: nil)
      command = %(psql "#{conn_str(db: db)}" #{params})
      if @final_name
        system! command
      else
        raise "wont run on live db: #{command}"
      end
    end

    def psql_query(sql, db: nil)
      command = %(psql "#{conn_str(db: db)}" -t -A -c "#{sql}")
      rows = `#{command}`.split("\n")
      rows.map { |i| i.split('|') }
    end

  end
end
