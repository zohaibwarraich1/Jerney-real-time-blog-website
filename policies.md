# eso-access-secret-policy
{
	"Version": "2012-10-17",
	"Statement": [
		{
			"Sid": "Statement1",
			"Effect": "Allow",
			"Action": [
				"secretsmanager:DescribeSecret",
				"secretsmanager:GetRandomPassword",
				"secretsmanager:GetResourcePolicy",
				"secretsmanager:GetSecretValue",
				"secretsmanager:ListSecretVersionIds"
			],
			"Resource": [
				"arn:aws:secretsmanager:us-east-1:162499216321:secret:prod/jerney/*"
			]
		}
	]
}
# Trust policy for eso-access-secret-policy role
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "Statement1",
            "Effect": "Allow",
            "Principal": {
                "Federated": "arn:aws:iam::162499216321:oidc-provider/oidc.eks.us-east-1.amazonaws.com/id/AAB702988D76E86B5FAFE1D2AE2183AE"
            },
            "Action": "sts:AssumeRoleWithWebIdentity",
            "Condition": {
                "StringEquals": {
                    "oidc.eks.us-east-1.amazonaws.com/id/AAB702988D76E86B5FAFE1D2AE2183AE:sub": "system:serviceaccount:jerney-ns:eso-sa"
                }
            }
        }
    ]
}
# route53 trust policy for IRSA
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "route53:GetChange",
      "Resource": "arn:aws:route53:::change/*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "route53:ChangeResourceRecordSets",
        "route53:ListResourceRecordSets"
      ],
      "Resource": "arn:aws:route53:::hostedzone/*"
    },
    {
      "Effect": "Allow",
      "Action": "route53:ListHostedZonesByName",
      "Resource": "*"
    }
  ]
}