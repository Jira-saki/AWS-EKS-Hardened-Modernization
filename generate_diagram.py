"""
generate_diagram.py
-------------------
Generates assets/AWS_EKS_Architecture.png — a full architecture diagram of the
AWS EKS Hardened Infrastructure using the mingrammer/diagrams library.

Usage:
    python3 generate_diagram.py

Requirements:
    pip install diagrams
    brew install graphviz  (or equivalent for your OS)
"""

from diagrams import Diagram, Cluster, Edge

# AWS
from diagrams.aws.network import ALB, InternetGateway, NATGateway
from diagrams.aws.security import WAF, KMS, IAMRole, Guardduty
from diagrams.aws.compute import EKS, EC2SpotInstance, EC2, ECR

# Kubernetes
from diagrams.k8s.compute import Pod, Deploy
from diagrams.k8s.network import SVC
from diagrams.k8s.clusterconfig import HPA

# On-Prem / OSS
from diagrams.onprem.ci import GithubActions
from diagrams.onprem.monitoring import Prometheus, Grafana
from diagrams.onprem.gitops import ArgoCD
from diagrams.onprem.security import Trivy

# ── Graph attributes ─────────────────────────────────────────────────────────
GRAPH_ATTR = {
    "fontsize":  "18",
    "fontname":  "Helvetica, sans-serif",
    "bgcolor":   "#0d1117",
    "pad":       "1.2",
    "splines":   "ortho",
    "nodesep":   "0.80",
    "ranksep":   "1.40",
    "dpi":       "150",
}

NODE_ATTR = {
    "fontsize": "12",
    "fontname": "Helvetica, sans-serif",
    "fontcolor": "#e6edf3",
}

CLUSTER_ATTR = {
    "fontsize":  "14",
    "fontname":  "Helvetica Bold, sans-serif",
    "fontcolor": "#e6edf3",
    "style":     "rounded",
    "penwidth":  "2.0",
}

# ── Edge colour palette ───────────────────────────────────────────────────────
# Blue   = live data / request traffic
# Green  = GitOps / control flow (Git manifest path)
# Amber  = metrics / observability / security relations
# Red    = autoscaling / provisioning
# Orange = image pull (ECR → Nodes)
EDGE_DATA   = Edge(color="#58a6ff", style="bold",   penwidth="2.5")
EDGE_CTRL   = Edge(color="#3fb950", style="dashed", penwidth="2.0")
EDGE_SCRAPE = Edge(color="#d29922", style="dotted", penwidth="2.0", label="/metrics")
EDGE_SCALE  = Edge(color="#f78166", style="dashed", penwidth="2.0", label="scales →")
EDGE_PROV   = Edge(color="#bc8cff", style="dashed", penwidth="2.0", label="provisions →")
EDGE_IMG    = Edge(color="#f0883e", style="dashed", penwidth="2.0", label="image pull\n(digest-pinned)")
EDGE_SEC    = Edge(color="#d29922", style="dotted", penwidth="1.5")
EDGE_DIM    = Edge(color="#484f58", style="dotted", penwidth="1.5")

# ── Diagram (Top-Bottom direction keeps nested VPC hierarchy readable) ────────
with Diagram(
    "AWS EKS Hardened Infrastructure",
    filename="assets/AWS_EKS_Architecture",
    outformat="png",
    direction="TB",
    graph_attr=GRAPH_ATTR,
    node_attr=NODE_ATTR,
    show=False,
):

    # ═════════════════════════════════════════════════════════════════════════
    # ROW 0 — External actors (rendered side-by-side via parallel definitions)
    # ═════════════════════════════════════════════════════════════════════════
    with Cluster(
        "External Traffic & Load Testing",
        graph_attr={**CLUSTER_ATTR, "bgcolor": "#161b22", "color": "#30363d"},
    ):
        k6 = EC2("k6 Load Generator\n(60 VUs spike)")

    with Cluster(
        "Supply Chain — CI/CD",
        graph_attr={**CLUSTER_ATTR, "bgcolor": "#161b22", "color": "#3fb950"},
    ):
        github_ci  = GithubActions("GitHub Actions\nCI Pipeline")
        trivy_scan = Trivy("Aqua Trivy\n(FS + Image scan)")
        ecr        = ECR("Amazon ECR\nPrivate Registry")

    # ═════════════════════════════════════════════════════════════════════════
    # ROW 1 — AWS Perimeter
    # ═════════════════════════════════════════════════════════════════════════
    with Cluster(
        "AWS Perimeter  ·  ap-northeast-1",
        graph_attr={**CLUSTER_ATTR, "bgcolor": "#161b22", "color": "#388bfd"},
    ):
        igw = InternetGateway("Internet Gateway")
        waf = WAF("AWS WAFv2\nOWASP CRS\nKnown Bad Inputs")

    # ═════════════════════════════════════════════════════════════════════════
    # VPC — 3-Tier network
    # ═════════════════════════════════════════════════════════════════════════
    with Cluster(
        "VPC — 3-Tier Network Segmentation",
        graph_attr={**CLUSTER_ATTR, "bgcolor": "#0d1117", "color": "#58a6ff"},
    ):

        # ── Tier 1: Public Subnet ─────────────────────────────────────────────
        # FIX: NAT Gateway must reside in a Public Subnet (needs direct IGW route
        # + Elastic IP) to provide outbound internet access for private subnets.
        with Cluster(
            "[ Public Subnet ]  ALB / WAF Termination  ·  NAT Gateway",
            graph_attr={**CLUSTER_ATTR, "bgcolor": "#161b22", "color": "#56d364"},
        ):
            alb = ALB("AWS ALB\n(internet-facing, IP target)")
            nat = NATGateway("NAT Gateway\n+ Elastic IP\n(private egress)")

        # ── Tier 2: Private Subnet — EKS ─────────────────────────────────────
        with Cluster(
            "[ Private Subnet ]  EKS Cluster  ·  Bottlerocket OS",
            graph_attr={**CLUSTER_ATTR, "bgcolor": "#161b22", "color": "#388bfd"},
        ):

            # EKS Control Plane
            with Cluster(
                "EKS Control Plane  (Private Endpoint Only)",
                graph_attr={**CLUSTER_ATTR, "bgcolor": "#0d1117", "color": "#58a6ff"},
            ):
                eks_cp  = EKS("EKS API\nprivate endpoint")
                kms_key = KMS("AWS KMS CMK\nenvelope encryption\nauto-rotation ✓")
                irsa    = IAMRole("IRSA / OIDC\nper-workload IAM")
                gd      = Guardduty("AWS GuardDuty\nEKS Runtime\nMonitoring")

            # System Node Group
            with Cluster(
                "System Node Group  ·  m5.large  ·  Managed / On-Demand  ·  Bottlerocket",
                graph_attr={**CLUSTER_ATTR, "bgcolor": "#0d1117", "color": "#3fb950"},
            ):
                coredns   = Pod("CoreDNS")
                alb_ctrl  = Deploy("AWS LB\nController")
                karpenter = Deploy("Karpenter\nController")
                argocd    = ArgoCD("ArgoCD\nGitOps")
                prom      = Prometheus("Prometheus\nOperator")
                grafana   = Grafana("Grafana\nDashboard")

            # Dynamic Compute (Karpenter-provisioned)
            with Cluster(
                "Dynamic Compute  ·  Karpenter / EC2 Spot  ·  c/m/r families  ·  Bottlerocket",
                graph_attr={**CLUSTER_ATTR, "bgcolor": "#0d1117", "color": "#f78166"},
            ):
                spot_nodes = EC2SpotInstance("EC2 Spot Nodes\n(JIT provisioned)")

                with Cluster(
                    "secure-api Deployment  ·  HPA: min=2 · max=10 · CPU=60%",
                    graph_attr={**CLUSTER_ATTR, "bgcolor": "#161b22", "color": "#d29922"},
                ):
                    # SVC exists in-cluster for DNS/internal traffic but is NOT
                    # in the ALB traffic path when using AWS VPC CNI IP target mode.
                    api_svc  = SVC("secure-api\nClusterIP SVC\n(internal DNS)")
                    hpa      = HPA("HPA\nautoscaling/v2")
                    api_pod1 = Pod("secure-api\nPod ①\n(ENI: VPC CNI)")
                    api_pod2 = Pod("secure-api\nPod ②\n(ENI: VPC CNI)")
                    api_pod3 = Pod("secure-api\nPod ③\n(ENI: VPC CNI)")

        # ── Tier 3: Data Subnet (isolated, no IGW route) ──────────────────────
        with Cluster(
            "[ Data Subnet ]  Isolated  ·  No route to IGW",
            graph_attr={**CLUSTER_ATTR, "bgcolor": "#161b22", "color": "#8b949e"},
        ):
            opensearch = EC2("Amazon OpenSearch\nSIEM / Audit Log\nKMS encrypted  ·  TLS 1.2+")

    # ═════════════════════════════════════════════════════════════════════════
    # CONNECTIONS
    # ═════════════════════════════════════════════════════════════════════════

    # 1. Live request traffic path
    #    FIX: ALB → Pods directly via AWS VPC CNI (IP target mode).
    #    The ALB TargetGroupBinding registers each Pod's VPC-routable ENI IP
    #    directly, bypassing kube-proxy / ClusterIP entirely.
    k6  >> EDGE_DATA >> igw
    igw >> EDGE_DATA >> waf
    waf >> EDGE_DATA >> alb
    alb >> Edge(color="#58a6ff", style="bold", penwidth="2.5",
                label="IP target mode\n(AWS VPC CNI)") >> [api_pod1, api_pod2, api_pod3]

    # 2. HPA scales pods on CPU threshold breach
    hpa >> EDGE_SCALE >> api_pod2

    # 3. Karpenter provisions EC2 Spot nodes when pods are Pending
    karpenter >> EDGE_PROV >> spot_nodes

    # 4. Prometheus scrapes /metrics; feeds Grafana
    prom >> EDGE_SCRAPE >> api_pod1
    prom - Edge(color="#d29922", style="solid", penwidth="2.0") - grafana

    # 5. Supply chain — corrected two-track flow:
    #    Track A (CI build):  GitHub Actions → Trivy → ECR → Pods (image pull)
    #    Track B (GitOps):    GitHub Actions → ArgoCD (Git manifest sync) → EKS
    #
    #    FIX: ArgoCD is a Git-driven engine, NOT an ECR consumer.
    #    ECR images are pulled directly by kubelet on the worker nodes.

    # Track A — build & image supply
    github_ci  >> EDGE_CTRL >> trivy_scan
    trivy_scan >> EDGE_CTRL >> ecr
    ecr        >> EDGE_IMG  >> [api_pod1, api_pod3]   # kubelet pulls digest-pinned image

    # Track B — GitOps declarative delivery
    github_ci >> Edge(color="#3fb950", style="dashed", penwidth="2.0",
                      label="Git commit\n(kustomize tag bump)") >> argocd
    argocd    >> EDGE_CTRL >> eks_cp

    # 6. KMS, IRSA, GuardDuty relations to EKS control plane
    kms_key - EDGE_SEC - eks_cp
    irsa    - EDGE_SEC - eks_cp
    gd      - EDGE_SEC - eks_cp

    # 7. Private egress via NAT (NAT now correctly in Public Subnet)
    nat - EDGE_DIM - eks_cp

    print("✅  Diagram written → assets/AWS_EKS_Architecture.png")
