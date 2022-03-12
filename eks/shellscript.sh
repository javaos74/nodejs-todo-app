
export ACCOUNT_ID=$(aws sts get-caller-identity --output text --query Account)
export AWS_REGION=$(curl -s 169.254.169.254/latest/dynamic/instance-identity/document | jq -r '.region')

# save .bash_profile
echo "export ACCOUNT_ID=${ACCOUNT_ID}" | tee -a ~/.bash_profile
echo "export AWS_REGION=${AWS_REGION}" | tee -a ~/.bash_profile
aws configure set default.region ${AWS_REGION}
aws configure --profile default list

#import key 
aws ec2 import-key-pair --key-name "eks-charles" --public-key-material fileb://./eks-charles.pub

aws sts get-caller-identity
#IAM OIDC Provider 생성
eksctl utils associate-iam-oidc-provider \
    --region ${AWS_REGION} \
    --cluster ${ekscluster_name} \
    --approve
#AWS Load Balancer 컨트롤러에 대한 IAM 정책 다운로드
curl -o iam_policy.json https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.4.0/docs/install/iam_policy.json

#AWSLoadBalancerControllerIAMPolicy IAM 정책 생성
aws iam create-policy \
    --policy-name AWSLoadBalancerControllerIAMPolicy \
    --policy-document file://./iam_policy.json

#AWS LoadBalancer Controller IAM 역할 및 Service Account 생성
eksctl create iamserviceaccount \
--cluster=${ekscluster_name} \
--namespace=kube-system \
--name=aws-load-balancer-controller \
--attach-policy-arn=arn:aws:iam::${ACCOUNT_ID}:policy/AWSLoadBalancerControllerIAMPolicy \
--override-existing-serviceaccounts \
--region ${AWS_REGION} \
--approve

#service account 체크 
kubectl get serviceaccounts -n kube-system aws-load-balancer-controller -o yaml

#인증서 관리자 설치 1.7.1 
kubectl apply --validate=false -f https://github.com/jetstack/cert-manager/releases/download/v1.7.1/cert-manager.yaml

#AWS Loadbalancer Controller Pod 설치
wget https://github.com/kubernetes-sigs/aws-load-balancer-controller/releases/download/v2.3.1/v2_3_1_full.yaml

#AWS Loadbalancer Controller Pod의 Deployment file에 지정된 cluster-name 값을 , 현재 배포한 Cluster name으로 변경합니다
#kind: ServiceAccount 섹션은 삭제하거나 주석처리하는 것이 좋습니다. 
sed 's/your-cluster-name/eks-charles/g' v2_3_1_full.yaml > new_v2_3_1_full.yaml 

#docker image pull secrete
export ECR_PWD=$(aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com)
kubectl create secret docker-registry myregistrykey --docker-server=230547346306.dkr.ecr.ap-northeast-2.amazonaws.com --docker-username=AWS --docker-password=${ECR_PWD}