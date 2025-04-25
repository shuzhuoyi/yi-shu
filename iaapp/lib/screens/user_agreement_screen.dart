import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

class UserAgreementScreen extends StatelessWidget {
  const UserAgreementScreen({super.key});

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
          '用户协议',
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
              '用户协议',
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
            const Text(
              '1. 接受条款',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '欢迎使用AiZhong应用（以下简称"本应用"）。本应用由AiZhong开发者（以下简称"我们"）提供。通过访问或使用本应用，您表示您已阅读、理解并同意接受本协议的所有条款和条件。如果您不同意本协议的任何部分，请不要使用本应用。',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[800],
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              '2. 账户注册与安全',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '2.1 您需要注册账户才能使用本应用的某些功能。您同意提供准确、完整、最新的信息，并同意及时更新您的信息。\n\n'
              '2.2 您负责维护您账户的保密性，并对所有使用您账户进行的活动负全部责任。\n\n'
              '2.3 如发现任何未经授权使用您账户的情况，您同意立即通知我们。',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[800],
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              '3. 用户行为规范',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '3.1 您同意不会使用本应用从事任何违法或不当的活动，包括但不限于：\n'
              '- 侵犯他人知识产权、隐私权或其他合法权益\n'
              '- 传播任何违法、有害、威胁、滥用、骚扰、侵权、诽谤、粗俗、淫秽或其他不当内容\n'
              '- 冒充他人或虚假陈述您与任何人或组织的关系\n'
              '- 干扰或破坏本应用及其服务器和网络\n'
              '- 收集或存储其他用户的个人信息\n\n'
              '3.2 我们保留在任何时候拒绝访问或终止账户的权利，而无需事先通知。',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[800],
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              '4. 知识产权',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '4.1 本应用及其内容（包括但不限于文本、图形、标志、图标、图像、音频和视频剪辑、数据编译和软件）均为我们或我们的许可方所有，受版权、商标和其他知识产权法律的保护。\n\n'
              '4.2 未经我们明确书面许可，您不得复制、修改、创建衍生作品、公开展示、表演、重新发布、下载、存储或传输本应用的任何内容。',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[800],
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              '5. 免责声明',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '5.1 本应用按"现状"和"可用"的基础提供，不提供任何明示或暗示的保证。\n\n'
              '5.2 我们不保证本应用将无错误或不间断运行，也不保证缺陷将被纠正，或本应用或提供它的服务器没有病毒或其他有害成分。',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[800],
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              '6. 责任限制',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '在法律允许的最大范围内，我们对任何直接、间接、偶然、特殊、惩罚性或后果性损害不承担责任，无论是基于保证、合同、侵权（包括疏忽）、产品责任或其他法律理论，也无论我们是否被告知此类损害的可能性。',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[800],
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              '7. 协议修改',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '我们保留随时修改本协议的权利。修改后的条款将在发布后立即生效。您继续使用本应用将被视为接受修改后的条款。',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[800],
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              '8. 适用法律',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '本协议受中华人民共和国法律管辖，不考虑法律冲突原则。',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[800],
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              '9. 联系我们',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '如果您对本协议有任何问题，请联系我们：zhong1231212@163.com',
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