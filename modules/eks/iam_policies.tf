data "aws_iam_policy_document" "eks_policy" {
  statement {
    actions = ["eks:DescribeCluster"]

    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "eks_policy" {
  name   = "eks_policy"
  role   = aws_iam_role.this.name
  policy = data.aws_iam_policy_document.eks_policy.json
}
