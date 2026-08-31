# A host on a laptop, with Multipass

`00-install` hardens a cluster on a host it is given; it never creates one. This is one
way to get that host locally. `03-provision` is the same thing on GCP, with Terraform.

```bash
multipass launch 22.04 --name k8slab --cpus 4 --memory 8G --disk 40G
multipass exec k8slab -- tee -a /home/ubuntu/.ssh/authorized_keys < ~/.ssh/id_ed25519_k8slab.pub
multipass info k8slab | awk '/IPv4/{print $2}'
```

Then the alias `00-install/.env` will point `VM_HOST` at:

```
Host k8slab
    HostName <the address printed above>
    User ubuntu
    IdentityFile ~/.ssh/id_ed25519_k8slab
    StrictHostKeyChecking accept-new
```

**The address is not stable.** A recreated VM gets a new one, and the symptom is a
`No route to host` that looks like the cluster is down — or, through a jump host,
`channel 0: open failed` and `stdio forwarding failed`. Update `HostName`, then
`ssh-keygen -R <old address>`, or the new host key is refused as a mismatch.

`multipass delete --purge k8slab` is the teardown that `make kill` deliberately does
not do: `kill` owns the lab, this owns the machine.
