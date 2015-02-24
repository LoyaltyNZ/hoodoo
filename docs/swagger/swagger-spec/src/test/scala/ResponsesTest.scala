import com.fasterxml.jackson.databind.JsonNode
import com.github.fge.jsonschema.core.exceptions.ProcessingException
import com.github.fge.jsonschema.main.{ JsonSchema, JsonSchemaFactory}
import com.github.fge.jsonschema.core.report.ProcessingReport
import com.github.fge.jackson.JsonLoader

import scala.io.Source

import org.junit.runner.RunWith
import org.scalatest.junit.JUnitRunner
import org.scalatest.FlatSpec
import org.scalatest.matchers.ShouldMatchers

@RunWith(classOf[JUnitRunner])
class ResponsesTest extends FlatSpec with ShouldMatchers with TestBase {
  val schema = readSchema(true)
  val factory = JsonSchemaFactory.byDefault()
  val jsonSchema = factory.getJsonSchema(schema.get("definitions").get("responses"))

  it should "validate multiple responses" in {
    val json = Source.fromFile("fixtures/v2.0/json/responses/multipleResponses.json").mkString
    val data = JsonLoader.fromString(json)
    val report = jsonSchema.validate(data)
    if(report.isSuccess == false)
      println(report)
    report.isSuccess should be (true)
  }
}
