import 'package:flutter/material.dart';
import 'admin_awards_management_page.dart';
import 'admin_awards_shortlisting_page.dart';
import 'admin_awards_verification_page.dart';

class AdminAwardsHubPage extends StatelessWidget {
  const AdminAwardsHubPage({super.key});
  static const _green=Color(0xFF165B5D),_orange=Color(0xFFF46627),_background=Color(0xFFF4EEE1);

  @override Widget build(BuildContext context)=>Scaffold(
    backgroundColor:_background,
    appBar:AppBar(backgroundColor:_green,foregroundColor:Colors.white,title:const Text('Guide Awards')),
    body:ListView(padding:const EdgeInsets.all(18),children:[
      Container(padding:const EdgeInsets.all(22),decoration:BoxDecoration(color:_green,borderRadius:BorderRadius.circular(22)),
        child:const Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Icon(Icons.workspace_premium_outlined,color:Colors.white,size:36),SizedBox(height:12),
          Text('Awards Administration',style:TextStyle(color:Colors.white,fontSize:23,fontWeight:FontWeight.w800)),
          SizedBox(height:6),Text('Manage the awards cycle, verification, judging and finalist selection.',style:TextStyle(color:Colors.white70,height:1.4)),
        ])),
      const SizedBox(height:18),
      _ActionCard(icon:Icons.settings_outlined,title:'Award Management',subtitle:'Manage stage, voting dates and results visibility.',
        onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const AdminAwardsManagementPage()))),
      const SizedBox(height:12),
      _ActionCard(icon:Icons.fact_check_outlined,title:'Verification',subtitle:'Review, verify or reject guide nominations.',
        onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const AdminAwardsVerificationPage()))),
      const SizedBox(height:12),
      _ActionCard(icon:Icons.leaderboard_outlined,title:'Judging & Shortlisting',subtitle:'Review rankings, score breakdowns and confirm finalists.',accent:_orange,
        onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const AdminAwardsShortlistingPage()))),
    ]));

}
class _ActionCard extends StatelessWidget{
 const _ActionCard({required this.icon,required this.title,required this.subtitle,required this.onTap,this.accent=AdminAwardsHubPage._green});
 final IconData icon; final String title,subtitle; final VoidCallback onTap; final Color accent;
 @override Widget build(BuildContext context)=>Material(color:Colors.white,borderRadius:BorderRadius.circular(20),child:InkWell(onTap:onTap,borderRadius:BorderRadius.circular(20),
  child:Padding(padding:const EdgeInsets.all(18),child:Row(children:[
   Container(width:52,height:52,decoration:BoxDecoration(color:accent.withValues(alpha:.10),borderRadius:BorderRadius.circular(16)),child:Icon(icon,color:accent)),
   const SizedBox(width:14),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    Text(title,style:const TextStyle(color:AdminAwardsHubPage._green,fontSize:17,fontWeight:FontWeight.w800)),const SizedBox(height:4),
    Text(subtitle,style:const TextStyle(color:Color(0xFF687269),height:1.35))])),
   const Icon(Icons.chevron_right_rounded,color:AdminAwardsHubPage._green)]))));
}
