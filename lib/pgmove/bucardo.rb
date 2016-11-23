require_relative 'helper'
require 'fileutils'

module Pgmove
  class Bucardo
    include Helper

    SCHEMA_PATH = "tmp/schema.sql"
    PGPASS_PATH = "#{Dir.home}/.pgpass"
    RELGROUP = "pgmove"
    SYNC_NAME = "pgmove"

    attr_reader :src_db, :dest_db

    def initialize(src_db, dest_db)
      @src_db = src_db
      @dest_db = dest_db
    end

    def setup
      create_dirs
      reset
      install
      copy_schema
      add_db
      add_tables
      add_sync
    end

    def bucardo(command, db: nil, env: {})
      db ||= "bucardo"
      system! "bucardo -U #{@src_db.user} -P #{@src_db.pass} -h #{@src_db.host} -p #{@src_db.port} -d #{db} #{command}", env: env
    end

    def reset
      stop
      reset_pgpass
      reset_src
      @dest_db.reset
    end

    def start_sync
      bucardo "start --log-destination log"
    end

    def status
      bucardo "status pgmove"
    end

    def stop
      if Dir.glob("tmp/*.pid").size > 0
        bucardo "stop"
        sleep 5
      end
    end

    def compare
      begin
        sconn = @src_db.pg_conn
        dconn = @dest_db.pg_conn
        format = "%-75s | %15s | %15s | %5s\n"
        printf format, "table", "source", "dest", "diff"
        puts "-" * (75 + 15 + 15 + 5 + 9)
        @src_db.tables.each do |t|
          src_count = @src_db.row_count(t, conn: sconn)
          dest_count = @dest_db.row_count(t, conn: dconn)
          marker = src_count == dest_count ? '' : "*"
          printf format, t, src_count, dest_count, marker
        end
      ensure
        sconn.close if sconn
        dconn.close if dconn
      end
    end

    def finalize
      stop
      reset_src
      @dest_db.finalize
    end

    private 

    def check_deps
      raise "#{@src_db.user} not a superuser" if not @src_db.superuser?
      raise "#{@dest_db.user} not a superuser" if not @dest_db.superuser?

    end

    def create_dirs
      FileUtils.mkdir_p "tmp"
      FileUtils.mkdir_p "log"
    end

    def reset_pgpass
      File.open(PGPASS_PATH, "w") do |f| 
        f.write "#{@src_db.host}:#{@src_db.port}:postgres:#{@src_db.user}:#{@src_db.pass}\n"
        f.chmod 0600
      end
    end

    def reset_src
      system! %(psql "#{@src_db.conn_str}" -c 'DROP schema if exists bucardo cascade')
      system! %(psql "#{@src_db.conn_str}" -c 'DROP database IF EXISTS bucardo')
      system! %(psql "#{@src_db.conn_str}" -c 'drop role IF EXISTS bucardo')
    end

    def install
      env = { "DBUSER" => @src_db.user }
      bucardo "install --batch --pid-dir tmp", db: "postgres", env: env
    end

    def copy_schema
      system! %(pg_dump "#{@src_db.conn_str}" -N bucardo --schema-only > #{SCHEMA_PATH})
      @dest_db.load_schema(SCHEMA_PATH)
    end

    def add_db
      bucardo "add db source_db #{@src_db.bucardo_conn_str}"
      bucardo "add db dest_db #{@dest_db.bucardo_conn_str}"
    end

    def add_tables
      bucardo "add all tables db=source_db relgroup=#{RELGROUP} -T public.spatial_ref_sys -N postgis"
      bucardo "add all sequences db=source_db relgroup=#{RELGROUP}"
    end

    def add_sync
      bucardo "add sync #{SYNC_NAME} relgroup=#{RELGROUP} dbs=source_db:source,dest_db:target onetimecopy=2"
    end

  end
end
