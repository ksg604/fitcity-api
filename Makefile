.PHONY: start
start:
	-@bin/rails db:migrate
	-@bin/rails db:seed
	-@bin/rails s -p 3001

.PHONY: start-https
start-https:
	-@bundle install
	-@bin/rails db:migrate
	-@bin/rails db:seed
	-@bin/rails server -b 'ssl://localhost:3001?key=./config/local_certs/localhost-key.pem&cert=./config/local_certs/localhost.pem'