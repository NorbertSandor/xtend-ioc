package ${package}

import com.erinors.ioc.shared.api.Module
import com.erinors.ioc.shared.api.Component

@Component
class HelloService
{
	def String sayHello(String to)
	'''Hello «to»!'''
}

@Module(components=#[HelloService])
interface ApplicationModule
{
	def HelloService helloService()
}

class Application
{
	def static void main(String[] args)
	{
		val module = ApplicationModule.Peer.initialize
		println(module.helloService.sayHello("World"))
	}
}
