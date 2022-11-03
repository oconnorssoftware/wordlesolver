# wordlesolver

![alt text](images/app_image.png?raw=true "App screenshot")
![alt text](images/front_end_stack.png?raw=true "App screenshot")

To Deploy Backend:
```
$cd back/terraform/

$terraform init

$terraform apply
```

To Deploy Frontend:  
navigate to front/terraform/main.tf  
update the frontend_bucket to use a bucket name of your choosing.  You can use a dynamically created value by uncommenting the random_pet resource and using it's value.    
```
$cd front/terraform

$terraform init

$terraform apply
```

Frontend: React app hosted in s3 deployed with terraform, built by webpack.

Backend: Lambda behind API Gateway deployed with terraform
Backend: Lambda behind API Gateway deployed with terraform