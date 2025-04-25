import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '隐私政策',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '隐私政策',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '最近更新日期：2023年10月1日',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              '保护您的隐私对我们至关重要。本隐私政策描述了我们收集、使用和披露您的个人信息的方式，以及您在使用AiZhong应用（以下简称"本应用"）时可以行使的相关权利。请您仔细阅读以下内容，了解我们对您个人信息的处理方式。',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[800],
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              '1. 我们收集的信息',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '1.1 您直接提供给我们的信息：\n'
              '- 注册信息：当您创建账户时，我们会收集您的用户名、密码和电子邮件地址。\n'
              '- 个人资料：您可以提供姓名、头像和其他个人信息来完善您的个人资料。\n'
              '- 通信内容：当您与我们联系时，我们会收集您提供的信息，包括您的问题或反馈。\n\n'
              '1.2 自动收集的信息：\n'
              '- 设备信息：我们会自动收集您的设备类型、操作系统版本、设备标识符和网络信息。\n'
              '- 使用数据：我们收集有关您如何使用本应用的信息，如浏览历史、搜索记录、观看记录和交互方式。\n'
              '- 位置信息：在您授权的情况下，我们可能会收集您的位置信息。',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[800],
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              '2. 信息使用',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '我们使用收集的信息来：\n'
              '- 提供、维护和改进本应用的服务\n'
              '- 为您创建和管理账户\n'
              '- 回应您的请求和问询\n'
              '- 个性化您的体验并提供定制内容和推荐\n'
              '- 发送服务相关通知和更新\n'
              '- 监控和分析使用趋势和偏好\n'
              '- 保护我们的服务安全并防止欺诈活动',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[800],
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              '3. 信息共享',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '我们不会出售您的个人信息。但在以下情况下，我们可能会共享您的信息：\n\n'
              '3.1 服务提供商：我们可能与帮助我们提供服务的第三方服务提供商分享信息，如云存储、数据分析和客户服务提供商。\n\n'
              '3.2 法律要求：如果法律要求我们这样做，或者为了回应合法的法律程序、保护我们的权利或防止非法活动。\n\n'
              '3.3 业务转让：如果我们参与合并、收购或资产出售，您的信息可能会作为此类交易的一部分被转让。\n\n'
              '3.4 经您同意：在其他情况下，我们会在获得您的同意后再共享您的个人信息。',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[800],
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              '4. 数据安全',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '我们采取合理的安全措施来保护您的个人信息不被未经授权的访问、使用或披露。然而，没有任何互联网传输或电子存储方法是100%安全的，我们不能保证绝对的安全性。',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[800],
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              '5. 您的权利',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '根据适用的数据保护法律，您可能有权：\n'
              '- 访问和获取我们持有的关于您的个人信息\n'
              '- 更正不准确的个人信息\n'
              '- 删除您的个人信息\n'
              '- 限制或反对我们处理您的个人信息\n'
              '- 数据可携带性\n'
              '- 撤销您之前给予的同意\n\n'
              '如需行使这些权利，请通过以下联系方式与我们联系。',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[800],
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              '6. 儿童隐私',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '本应用不面向13岁以下的儿童。我们不会故意收集13岁以下儿童的个人信息。如果您是父母或监护人，并且您认为您的孩子向我们提供了个人信息，请联系我们，我们将采取措施删除此类信息。',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[800],
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              '7. 隐私政策更新',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '我们可能会不时更新本隐私政策。在做出重大变更时，我们会通过在本应用中发布通知或发送电子邮件来通知您。我们鼓励您定期查看本政策，了解我们如何保护您的信息。',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[800],
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              '8. 联系我们',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '如果您对本隐私政策有任何问题或疑虑，请联系我们：zhong1231212@163.com',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[800],
                height: 1.5,
              ),
            ),
            const SizedBox(height: 40),
            Center(
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.primaryColor,
                  padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  '我已阅读并同意',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
} 