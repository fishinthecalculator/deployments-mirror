##
# Deployments
#
# @file
# @version 0.1

# Introduction of the 'guix-deployments' channel.
channel_intro_commit = 9d101a2b1f38571e75e7d256bbc8d754177d11f3
channel_intro_signer = 8D10 60B9 6BB8 292E 829B  7249 AED4 1CC1 93B7 01E2

authenticate:
	echo "Authenticating Git checkout..." ;	\
	guix git authenticate					\
	    --cache-key=channels/guix --stats			\
	    "$(channel_intro_commit)" "$(channel_intro_signer)"

# end
