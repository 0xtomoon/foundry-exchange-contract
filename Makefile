-include .env

build:; forge build

deploy-local:
	$(MAKE) deploy RPC_URL=localhost EXTRA_FLAGS=

deploy-baseSepolia:
	$(MAKE) deploy RPC_URL=baseSepolia EXTRA_FLAGS="--verify --etherscan-api-key ${BASE_SEPOLIA_ETHERSCAN_API_KEY} --verifier-url ${BASE_SEPOLIA_ETHERSCAN_API_URL} --slow"

deploy:
	@echo "Running deploy '$(RPC_URL)'"
	@rm -rf out && \
	forge script script/DeployETHUSDCExchange.s.sol --rpc-url $(RPC_URL) \
		--private-key $(DEPLOYER_PRIVATE_KEY) --broadcast $(EXTRA_FLAGS) -vvvv
