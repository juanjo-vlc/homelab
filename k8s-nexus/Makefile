.DEFAULT_GOAL := help
NAMESPACE := $(or $(NAMESPACE), nexus-rm)
DEPLOYMENT_NAME := $(or $(DEPLOYMENT_NAME), nexus-rm)
NXPWD := $(or $(NXPWD), chang3m3)
NXDOMAIN := $(or $(NXDOMAIN), nexus.aks.garciaamaya.com)

available_goals := repo-add namespace install patch update-password update-realms enable-anonymous create-repos uninstall

.PHONY: deploy configure help
.PHONY: $(available_goals)

help:
	@echo "Available goals:"
	@echo "$(available_goals)"

deploy: install patch

configure: update-password enable-anonymous update-realms create-repos


repo-add:
	@echo "Adding helm repo"
	helm repo add sonatype https://sonatype.github.io/helm3-charts/


namespace:
	@echo "Creating namespace $(NAMESPACE)"
	kubectl create namespace $(NAMESPACE)


install:
	@echo "Installing helm chart"
	helm upgrade --install -f values.yaml -n $(NAMESPACE) $(DEPLOYMENT_NAME) sonatype/nexus-repository-manager

patch:
	@echo "Patching service"
	kubectl -n nexus-rm patch svc nexus-rm-nexus-repository-manager -p '{"spec":{"ports":[{"name":"docker-port","port":8082,"targetPort":8082}]}}'
	@echo "Patching ingress"
	kubectl -n nexus-rm patch ingress nexus-rm-nexus-repository-manager  --type=json -p '[{"op":"add","path":"/spec/rules/0/http/paths/-","value":{"path":"/v2","pathType":"Prefix","backend":{"service":{"name":"nexus-rm-nexus-repository-manager","port":{"number":8082}}}}}]'

update-password:
	@echo "Updating original password"
	$(eval POD_NAME := $(shell kubectl get pods --namespace $(NAMESPACE) -l "app.kubernetes.io/name=nexus-repository-manager,app.kubernetes.io/instance=nexus-rm" -o jsonpath="{.items[0].metadata.name}"))
	$(eval NX_ORIGINAL_PWD := $(shell kubectl exec -n $(NAMESPACE) $(POD_NAME) -- cat /nexus-data/admin.password))
	@echo "Retrieved initial password: $(NX_ORIGINAL_PWD)"
	curl -X 'PUT' -i \
		'https://$(NXDOMAIN)/service/rest/v1/security/users/admin/change-password' \
		-H 'accept: application/json' \
		-H 'Content-Type: text/plain' \
		-d "$(NXPWD)" \
		-u "admin:$(NX_ORIGINAL_PWD)"

enable-anonymous:
	@echo 'Enabling anonymous access'
	curl -X 'PUT' -i \
		'https://$(NXDOMAIN)/service/rest/v1/security/anonymous' \
		-H 'accept: application/json' \
		-H 'Content-Type: application/json' \
		-u "admin:$(NXPWD)" \
		-d '{"enabled": true,"userId": "anonymous","realmName": "NexusAuthorizingRealm"}'

update-realms:
	@echo 'Updating realms configuration'
	curl -X 'PUT' -i \
		'https://$(NXDOMAIN)/service/rest/v1/security/realms/active' \
			-H 'accept: application/json' \
			-H 'Content-Type: application/json' \
			-d '["NexusAuthenticatingRealm","NexusAuthorizingRealm","DockerToken", "NpmToken"]' \
			-u "admin:$(NXPWD)"

create-repos:
	@echo 'Creating docker proxied repository'
	curl -X POST -i \
		'https://$(NXDOMAIN)/service/rest/v1/repositories/docker/proxy' \
		-d @repo-proxied-dockerhub.json \
		-H 'accept: application/json' \
		-H 'Content-Type: application/json' \
		-u "admin:$(NXPWD)"
	@echo 'Creating pypi proxied repository'
	curl -X POST -i \
		'https://$(NXDOMAIN)/service/rest/v1/repositories/pypi/proxy' \
		-d @repo-proxied-pypi.json \
		-H 'accept: application/json' \
		-H 'Content-Type: application/json' \
		-u "admin:$(NXPWD)"
	@echo 'Creating npm proxied repository'
	curl -X POST -i \
		'https://$(NXDOMAIN)/service/rest/v1/repositories/npm/proxy' \
		-d @repo-proxied-npm.json \
		-H 'accept: application/json' \
		-H 'Content-Type: application/json' \
		-u "admin:$(NXPWD)"

uninstall:
	helm uninstall -n $(NAMESPACE) $(DEPLOYMENT_NAME)