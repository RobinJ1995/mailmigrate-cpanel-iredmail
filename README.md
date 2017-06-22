# Migrate e-mail addresses/forwards from CPanel to iRedMail

`export.sh` outputs a list of all e-mail addresses and forwarders on a CPanel server in a format which `import.sh` can import into iRedMail (SQL).

## Usage

1. On the source server, run `bash export.sh > exported`.
2. Copy `exported` into the same folder as the `import.sh` script (and `config.sh`) on the target iRedMail (SQL) server.
3. Set the correct parameters in `config.sh` on the target server.
4. Run `config.sh` on the target server.

## Note

These scripts have been written for a very specific setup, and are unlikely to work for any other setups. The only scenario where this script will work is if you wish to migrate all your e-mail addresses from a CPanel server to an iRedMail server with MariaDB/MySQL. I haven't looked into where/how CPanel stores catch-all e-mail addresses, but the scripts haven't been tested with those, either.

